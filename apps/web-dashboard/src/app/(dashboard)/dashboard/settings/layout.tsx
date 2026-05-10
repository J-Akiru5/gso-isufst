import { Metadata } from "next"
import { Separator } from "@/components/ui/separator"
import { SidebarNav } from "@/components/settings/sidebar-nav"

export const metadata: Metadata = {
  title: "Settings",
  description: "Manage system configurations, users, and lookup tables.",
}

const sidebarNavItems = [
  {
    title: "Users",
    href: "/dashboard/settings/users",
  },
  {
    title: "Roles",
    href: "/dashboard/settings/roles",
  },
  {
    title: "Departments",
    href: "/dashboard/settings/departments",
  },
  {
    title: "Locations",
    href: "/dashboard/settings/locations",
  },
  {
    title: "Categories",
    href: "/dashboard/settings/categories",
  },
]

interface SettingsLayoutProps {
  children: React.ReactNode
}

export default function SettingsLayout({ children }: SettingsLayoutProps) {
  return (
    <div className="space-y-6 p-10 pb-16 hidden md:block">
      <div className="space-y-0.5">
        <h2 className="text-2xl font-bold tracking-tight">Settings</h2>
        <p className="text-muted-foreground">
          Manage system configurations, users, and lookup tables.
        </p>
      </div>
      <Separator className="my-6" />
      <div className="flex flex-col space-y-8 lg:flex-row lg:space-x-12 lg:space-y-0">
        <aside className="-mx-4 lg:w-1/5">
          <SidebarNav items={sidebarNavItems} />
        </aside>
        <div className="flex-1 lg:max-w-4xl">{children}</div>
      </div>
    </div>
  )
}
