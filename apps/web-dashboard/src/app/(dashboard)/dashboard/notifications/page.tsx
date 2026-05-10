import { Metadata } from "next"
import { NotificationsClient } from "@/components/dashboard/notifications-client"

export const metadata: Metadata = {
  title: "Notifications | GSO Portal",
  description: "View your system notifications and alerts.",
}

export default function NotificationsPage() {
  return <NotificationsClient />
}
