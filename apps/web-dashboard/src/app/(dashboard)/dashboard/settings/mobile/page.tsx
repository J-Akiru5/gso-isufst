import { Metadata } from "next"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { 
  Smartphone, 
  Download, 
  ShieldCheck, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  History,
  Info,
  QrCode
} from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"

export const metadata: Metadata = {
  title: "Mobile App Settings",
  description: "Download and manage the ISUFST GSO Mobile App distribution.",
}

export default function MobileSettingsPage() {
  const currentVersion = "1.0.1"
  const apkPath = "/distribution/isufst_gso.apk"
  const apkSize = "84.5 MB"
  const releaseDate = "May 10, 2026"

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col gap-2">
        <h3 className="text-2xl font-bold tracking-tight">Mobile Application Hub</h3>
        <p className="text-muted-foreground max-w-2xl">
          Deploy and manage the official Android application. This hub serves as the primary distribution point for campus technicians and administrative staff.
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Main Download Card */}
        <Card className="lg:col-span-2 overflow-hidden border-brand-primary/20 bg-gradient-to-br from-brand-primary/5 via-transparent to-transparent">
          <CardHeader className="pb-4">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-4">
                <div className="p-3 rounded-2xl bg-brand-primary text-primary-foreground shadow-lg shadow-brand-primary/20">
                  <Smartphone className="h-6 w-6" />
                </div>
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <CardTitle className="text-xl">Production Build</CardTitle>
                    <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 border-emerald-500/20 px-2 py-0">
                      Stable
                    </Badge>
                  </div>
                  <CardDescription className="flex items-center gap-2">
                    <span className="font-semibold text-foreground">Version {currentVersion}</span>
                    <span className="text-muted-foreground">•</span>
                    <span>{apkSize}</span>
                  </CardDescription>
                </div>
              </div>
              <div className="hidden sm:block">
                <p className="text-xs text-right text-muted-foreground">Released on</p>
                <p className="text-xs font-medium text-right">{releaseDate}</p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid sm:grid-cols-2 gap-6">
              <div className="space-y-4">
                <p className="text-sm leading-relaxed text-muted-foreground">
                  The latest build includes the complete GSO ecosystem: Inventory Control, Maintenance Ticketing, and Equipment Borrowing modules.
                </p>
                <div className="flex flex-col gap-3">
                  <Button className="w-full h-12 gap-2 shadow-md hover:shadow-lg transition-all" asChild>
                    <a href={apkPath} download>
                      <Download className="h-4 w-4" />
                      Download Latest APK
                    </a>
                  </Button>
                </div>
              </div>
              
              <div className="bg-muted/30 rounded-xl p-4 border border-border/50 flex flex-col items-center justify-center gap-3 text-center">
                <div className="w-24 h-24 bg-white rounded-lg flex items-center justify-center border shadow-sm relative group cursor-help">
                   <QrCode className="h-16 w-16 text-slate-300 group-hover:text-brand-primary transition-colors" />
                   <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-white/90 rounded-lg">
                     <p className="text-[10px] font-bold text-brand-primary uppercase px-2">Scan to Download</p>
                   </div>
                </div>
                <div>
                  <p className="text-xs font-semibold mb-1">Direct Download QR</p>
                  <p className="text-[10px] text-muted-foreground px-4 italic">
                    Scan with any Android camera to download directly to device
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Status/Compatibility Card */}
        <Card className="flex flex-col h-full">
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-emerald-500" />
              Build Information
            </CardTitle>
          </CardHeader>
          <CardContent className="flex-1 space-y-4">
            <div className="space-y-3">
              <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">Architecture:</span>
                <span className="font-medium">universal (arm64/v7a)</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">Min Android:</span>
                <span className="font-medium">8.0 (Oreo)</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">Signature:</span>
                <span className="text-emerald-600 font-medium">Verified (ISUFST)</span>
              </div>
            </div>
            
            <Separator />
            
            <div className="space-y-3 pt-1">
              <p className="text-[11px] font-bold uppercase text-muted-foreground tracking-wider">Requirement Check</p>
              <ul className="space-y-2">
                {[
                  "Official Gmail Login",
                  "Stable Internet Connection",
                  "80MB Storage Space",
                  "ISUFST Approval"
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-2 text-xs">
                    <CheckCircle2 className="h-3 w-3 text-emerald-500" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Release Notes */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <History className="h-4 w-4" />
              Release Notes
            </CardTitle>
            <Badge variant="outline" className="text-[10px]">v{currentVersion}</Badge>
          </CardHeader>
          <CardContent className="space-y-4 pt-2">
             <div className="space-y-3">
               <div className="flex items-start gap-3">
                 <Badge className="bg-blue-500/10 text-blue-600 hover:bg-blue-500/20 border-none h-5">NEW</Badge>
                 <p className="text-sm">Added Real-time Philippine Standard Time synchronization.</p>
               </div>
               <div className="flex items-start gap-3">
                 <Badge className="bg-blue-500/10 text-blue-600 hover:bg-blue-500/20 border-none h-5">FIX</Badge>
                 <p className="text-sm">Corrected Inventory Audit Log status mapping for Borrowed items.</p>
               </div>
               <div className="flex items-start gap-3">
                 <Badge className="bg-blue-500/10 text-blue-600 hover:bg-blue-500/20 border-none h-5">IMP</Badge>
                 <p className="text-sm">Optimized image compression for maintenance request attachments.</p>
               </div>
             </div>
          </CardContent>
        </Card>

        {/* Security Warning */}
        <Card className="border-yellow-500/20 bg-yellow-500/5">
          <CardHeader>
             <CardTitle className="text-base flex items-center gap-2 text-yellow-700 dark:text-yellow-500">
               <AlertTriangle className="h-4 w-4" />
               Security Notice
             </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <p className="text-sm text-yellow-800/80 dark:text-yellow-500/80 leading-relaxed">
              Since this application is distributed outside the Google Play Store, you must enable <strong>"Install from Unknown Sources"</strong> in your device settings.
            </p>
            <Button variant="outline" size="sm" className="bg-yellow-500/10 border-yellow-500/20 text-yellow-700 dark:text-yellow-500 hover:bg-yellow-500/20 gap-2">
              <Info className="h-3 w-3" />
              How to enable?
            </Button>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-4">
          <CardTitle>System Distribution Status</CardTitle>
          <CardDescription>Real-time telemetry for the mobile application backend.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: "Auth Server", status: "Online", color: "text-emerald-500" },
              { label: "Storage CDN", status: "Active", color: "text-emerald-500" },
              { label: "Push Service", status: "Active", color: "text-emerald-500" },
              { label: "Update Agent", status: "Polling", color: "text-blue-500" },
            ].map((stat, i) => (
              <div key={i} className="p-4 rounded-xl bg-muted/20 border flex flex-col gap-1">
                <span className="text-[10px] font-bold uppercase text-muted-foreground">{stat.label}</span>
                <span className={`text-sm font-bold ${stat.color} flex items-center gap-2`}>
                  <span className={`w-2 h-2 rounded-full bg-current animate-pulse`} />
                  {stat.status}
                </span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
