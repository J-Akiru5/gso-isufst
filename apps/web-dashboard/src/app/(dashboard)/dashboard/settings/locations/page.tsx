import { Metadata } from "next"
import { LocationsSettingsClient } from "@/components/settings/locations-settings-client"

export const metadata: Metadata = {
  title: "Locations Management | Settings",
  description: "Manage buildings and rooms across the campus.",
}

export default function LocationsSettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium">Locations</h3>
        <p className="text-sm text-muted-foreground">
          View and manage the buildings and rooms.
        </p>
      </div>
      <LocationsSettingsClient />
    </div>
  )
}
