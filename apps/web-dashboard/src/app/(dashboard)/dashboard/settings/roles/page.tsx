import { Metadata } from "next"
import { RolesSettingsClient } from "@/components/settings/roles-settings-client"

export const metadata: Metadata = {
  title: "Roles Management | Settings",
  description: "Manage system roles.",
}

export default function RolesSettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium">Roles</h3>
        <p className="text-sm text-muted-foreground">
          View and manage the roles available in the system.
        </p>
      </div>
      <RolesSettingsClient />
    </div>
  )
}
