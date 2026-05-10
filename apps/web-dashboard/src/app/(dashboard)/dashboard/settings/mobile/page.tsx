import { Metadata } from "next"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Smartphone, Download, ShieldCheck, AlertTriangle } from "lucide-react"

export const metadata: Metadata = {
  title: "Mobile App Settings",
  description: "Download and install the ISUFST GSO Mobile App.",
}

export default function MobileSettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium">Mobile Application</h3>
        <p className="text-sm text-muted-foreground">
          Access the ISUFST GSO Portal on the go with our Android application.
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card className="border-brand-primary/20 bg-brand-primary/5">
          <CardHeader>
            <div className="flex items-center gap-2">
              <div className="p-2 rounded-lg bg-brand-primary text-primary-foreground">
                <Smartphone className="h-5 w-5" />
              </div>
              <div>
                <CardTitle>Download APK</CardTitle>
                <CardDescription>Version 1.0.0 (Stable)</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm">
              The mobile app allows technicians to handle maintenance requests and inventory management directly from the field.
            </p>
            <Button className="w-full h-12 gap-2" asChild>
              <a href="#" target="_blank" rel="noopener noreferrer">
                <Download className="h-4 w-4" />
                Download for Android
              </a>
            </Button>
            <p className="text-[11px] text-center text-muted-foreground">
              Size: ~25MB • Updated: May 10, 2026
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Security Verification</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-start gap-3">
              <ShieldCheck className="h-5 w-5 text-green-500 shrink-0 mt-0.5" />
              <div className="space-y-1">
                <p className="text-sm font-medium">Official Build</p>
                <p className="text-xs text-muted-foreground">
                  This APK is signed by the ISUFST ICT Office and is safe to install.
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-yellow-500 shrink-0 mt-0.5" />
              <div className="space-y-1">
                <p className="text-sm font-medium">Unknown Sources</p>
                <p className="text-xs text-muted-foreground">
                  You may need to enable "Install from unknown sources" in your Android settings to install this APK.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Installation Guide</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-6 md:grid-cols-3">
            <div className="space-y-2">
              <div className="h-8 w-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-sm">1</div>
              <p className="text-sm font-medium">Download</p>
              <p className="text-xs text-muted-foreground">Click the download button above to get the APK file.</p>
            </div>
            <div className="space-y-2">
              <div className="h-8 w-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-sm">2</div>
              <p className="text-sm font-medium">Authorize</p>
              <p className="text-xs text-muted-foreground">If prompted, allow your browser to install apps from unknown sources.</p>
            </div>
            <div className="space-y-2">
              <div className="h-8 w-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-sm">3</div>
              <p className="text-sm font-medium">Sign In</p>
              <p className="text-xs text-muted-foreground">Open the app and sign in with your institutional credentials.</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
