import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

// Constants
const FIREBASE_MESSAGING_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

// Standard CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    console.log("Webhook payload received:", payload);

    // Ensure this is an INSERT trigger
    if (payload.type !== "INSERT" || !payload.record) {
      return new Response(JSON.stringify({ error: "Invalid payload, ignoring." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const notification = payload.record;

    // Initialize Supabase Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Supabase credentials not found in environment.");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get the user's FCM tokens
    const { data: pushTokens, error: tokensError } = await supabase
      .from("push_tokens")
      .select("token")
      .eq("user_id", notification.user_id)
      .eq("is_active", true);

    if (tokensError) {
      throw new Error(`Failed to fetch push tokens: ${tokensError.message}`);
    }

    if (!pushTokens || pushTokens.length === 0) {
      console.log(`No active push tokens found for user ${notification.user_id}`);
      return new Response(JSON.stringify({ message: "No active tokens for user." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // Prepare Firebase Auth
    const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
    if (!serviceAccountStr) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY not found in edge function secrets.");
    }

    const serviceAccount = JSON.parse(serviceAccountStr);

    // Authenticate with Google
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key.replace(/\\n/g, "\n"),
      scopes: [FIREBASE_MESSAGING_SCOPE],
    });

    const accessToken = await jwtClient.getAccessToken();
    const projectId = serviceAccount.project_id;

    // Dispatch a push notification for each token
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const sendPromises = pushTokens.map(async (tokenRow) => {
      const message = {
        message: {
          token: tokenRow.token,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: {
            type: notification.type,
            reference_id: notification.reference_id || "",
          },
        },
      };

      const res = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken.token}`,
        },
        body: JSON.stringify(message),
      });

      if (!res.ok) {
        const errText = await res.text();
        console.error(`FCM error for token ${tokenRow.token}:`, errText);
        // If token is unregistered, we should deactivate it in DB
        if (errText.includes("UNREGISTERED")) {
          await supabase.from("push_tokens").update({ is_active: false }).eq("token", tokenRow.token);
        }
      } else {
        console.log(`Notification sent successfully to ${tokenRow.token}`);
      }
    });

    await Promise.all(sendPromises);

    return new Response(JSON.stringify({ success: true, count: pushTokens.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: any) {
    console.error("Error sending push notification:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
