import { Metadata } from "next"
import { CategoriesSettingsClient } from "@/components/settings/categories-settings-client"

export const metadata: Metadata = {
  title: "Categories Management | Settings",
  description: "Manage maintenance and inventory categories.",
}

export default function CategoriesSettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium">Categories</h3>
        <p className="text-sm text-muted-foreground">
          View and manage categories used for maintenance requests and inventory items.
        </p>
      </div>
      <CategoriesSettingsClient />
    </div>
  )
}
