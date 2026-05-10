import { Metadata } from "next"
import { UsersSettingsClient } from "@/components/settings/users-settings-client"

export const metadata: Metadata = {
  title: "User Management | Settings",
  description: "Manage users, approve registrations, and assign roles.",
}

export default function UsersSettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium">User Management</h3>
        <p className="text-sm text-muted-foreground">
          View all registered users, approve pending accounts, and configure their roles.
        </p>
      </div>
      <UsersSettingsClient />
    </div>
  )
}
