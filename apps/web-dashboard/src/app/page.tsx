import Link from 'next/link'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/server'

export default async function LandingPage() {
  const supabase = await createClient()
  const { data: versionData } = await supabase
    .from('app_versions')
    .select('*')
    .eq('platform', 'android')
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .limit(1)
    .single()

  const currentVersion = versionData?.version_number || "1.0.0"
  const apkPath = versionData?.download_url || "/distribution/isufst_gso.apk"
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 selection:bg-indigo-500/30 selection:text-indigo-200 overflow-x-hidden font-sans">
      {/* Background Effects */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] rounded-full bg-indigo-600/20 blur-[120px]" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-blue-600/20 blur-[120px]" />
        <div className="absolute top-[40%] left-[60%] w-[30%] h-[30%] rounded-full bg-violet-600/10 blur-[100px]" />
        <div className="absolute inset-0 bg-[url('/assets/grid-pattern.svg')] opacity-[0.03]" />
      </div>

      {/* Navigation */}
      <nav className="fixed top-0 w-full z-50 transition-all duration-300 bg-slate-950/50 backdrop-blur-xl border-b border-white/5">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="flex justify-between h-20 items-center">
            <div className="flex items-center gap-6 group cursor-pointer">
              <div className="flex items-center -space-x-3">
                <div className="relative w-12 h-12 rounded-full overflow-hidden border-2 border-white/10 shadow-xl z-20 bg-slate-900">
                  <Image src="/assets/ISUFST_LOGO.png" alt="ISUFST Logo" fill className="object-contain p-1" />
                </div>
                <div className="relative w-12 h-12 rounded-full overflow-hidden border-2 border-white/10 shadow-xl z-10 bg-slate-900">
                  <Image src="/assets/GSO.png" alt="GSO Logo" fill className="object-cover" />
                </div>
              </div>
              <div className="flex flex-col">
                <span className="font-bold text-lg leading-tight tracking-tight text-white">
                  ISUFST GSO
                </span>
                <span className="text-[10px] uppercase tracking-[0.2em] text-indigo-400 font-semibold">
                  Dingle Campus
                </span>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <Link
                href="/dashboard"
                className="relative inline-flex items-center justify-center px-6 py-2.5 text-sm font-semibold text-white transition-all duration-300 bg-indigo-600/90 rounded-full hover:bg-indigo-500 hover:scale-105 hover:shadow-[0_0_20px_rgba(79,70,229,0.4)] ring-1 ring-white/10"
              >
                Access Portal
              </Link>
            </div>
          </div>
        </div>
      </nav>


      <main className="relative z-10 pt-32 pb-20 lg:pt-48 lg:pb-32">
        {/* Hero Section */}
        <div className="max-w-7xl mx-auto px-6 lg:px-8 text-center">
          <div className="inline-flex items-center px-4 py-2 rounded-full text-xs font-medium bg-indigo-500/10 text-indigo-300 mb-8 border border-indigo-500/20 backdrop-blur-md shadow-inner">
            <span className="flex w-2 h-2 rounded-full bg-indigo-400 mr-2 animate-pulse" />
            Official Portal • ISUFST Dingle Campus
          </div>
          
          <h1 className="text-5xl sm:text-7xl font-extrabold tracking-tight mb-8 leading-[1.1]">
            Intelligent Operations <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 via-blue-400 to-cyan-400">
              For A Modern Campus
            </span>
          </h1>
          
          <p className="max-w-2xl mx-auto text-lg sm:text-xl text-slate-400 leading-relaxed mb-12 font-light">
            A unified digital ecosystem designed to streamline inventory control, track maintenance requests, and simplify equipment borrowing for the ISUFST community.
          </p>
          
          <div className="flex flex-col sm:flex-row justify-center gap-5">
            <Link
              href="#download"
              className="group relative inline-flex items-center justify-center px-8 py-4 text-base font-semibold rounded-2xl text-white bg-gradient-to-b from-indigo-500 to-indigo-600 hover:from-indigo-400 hover:to-indigo-500 transition-all shadow-[0_0_30px_rgba(79,70,229,0.3)] hover:shadow-[0_0_40px_rgba(79,70,229,0.5)] hover:-translate-y-1 overflow-hidden ring-1 ring-indigo-400/50"
            >
              <div className="absolute inset-0 bg-[linear-gradient(to_right,transparent,rgba(255,255,255,0.1),transparent)] translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-1000" />
              <span>Get Mobile App</span>
              <svg className="w-5 h-5 ml-2 group-hover:translate-y-1 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
            </Link>
          </div>
        </div>

        {/* Features Grid */}
        <div className="max-w-7xl mx-auto px-6 lg:px-8 mt-32">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[
              { title: 'Smart Inventory', desc: 'Real-time tracking of campus assets with detailed audit logs and stock level alerts.', icon: '📦', color: 'from-blue-500/20 to-cyan-500/5' },
              { title: 'Maintenance Hub', desc: 'Centralized ticketing for facility repairs, complete with status tracking and technician assignment.', icon: '🛠️', color: 'from-indigo-500/20 to-purple-500/5' },
              { title: 'Borrowing System', desc: 'Frictionless digital workflow for requesting and returning school equipment securely.', icon: '🔄', color: 'from-violet-500/20 to-fuchsia-500/5' },
            ].map((feature, i) => (
              <div key={i} className="group relative p-8 rounded-3xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all duration-500 hover:-translate-y-2 overflow-hidden">
                <div className={`absolute inset-0 bg-gradient-to-br ${feature.color} opacity-0 group-hover:opacity-100 transition-opacity duration-500`} />
                <div className="relative z-10">
                  <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-2xl mb-6 shadow-inner group-hover:scale-110 transition-transform duration-500">
                    {feature.icon}
                  </div>
                  <h3 className="text-xl font-semibold text-white mb-3">{feature.title}</h3>
                  <p className="text-slate-400 leading-relaxed text-sm">{feature.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Download Section */}
        <section id="download" className="max-w-7xl mx-auto px-6 lg:px-8 mt-32 pt-20 border-t border-white/5">
          <div className="relative rounded-[2.5rem] overflow-hidden border border-white/10 bg-slate-900/50 backdrop-blur-sm p-10 lg:p-16 flex flex-col lg:flex-row items-center justify-between gap-12">
            {/* Background Glow */}
            <div className="absolute top-1/2 left-1/4 -translate-y-1/2 w-96 h-96 bg-indigo-600/30 blur-[100px] rounded-full pointer-events-none" />
            
            <div className="relative z-10 max-w-xl">
              <h2 className="text-3xl lg:text-5xl font-bold text-white mb-6 tracking-tight">
                GSO Services in <br />Your Pocket
              </h2>
              <p className="text-slate-400 text-lg mb-8 leading-relaxed font-light">
                Download the official Android application to submit maintenance requests, browse available equipment, and receive real-time status updates on the go.
              </p>
              
              <div className="flex flex-col sm:flex-row items-start gap-6">
                <a
                  href={apkPath}
                  className="group relative inline-flex items-center gap-3 bg-white text-slate-900 px-8 py-4 rounded-2xl font-bold hover:bg-slate-100 transition-all shadow-[0_0_20px_rgba(255,255,255,0.1)] hover:shadow-[0_0_30px_rgba(255,255,255,0.2)] hover:-translate-y-1"
                >
                  <svg className="w-6 h-6 group-hover:animate-bounce" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M17.523 15.3414L20.355 18.1734L18.941 19.5874L16.109 16.7554V21H14.109V13H22.109V15H17.523V15.3414ZM7.109 13H12.109V15H9.109V17H12.109V19H9.109V21H7.109V13ZM2 13H5V21H2V13ZM3 15V19H4V15H3Z" />
                  </svg>
                  <span>Download APK <span className="text-slate-500 font-normal ml-1 text-sm">(v{currentVersion})</span></span>
                </a>
              </div>
            </div>

            <div className="relative z-10 w-full max-w-md bg-white/[0.03] border border-white/10 rounded-3xl p-8 backdrop-blur-md">
              <h3 className="font-semibold text-white mb-6 flex items-center gap-3 text-lg">
                <span className="flex items-center justify-center w-8 h-8 rounded-full bg-indigo-500/20 text-indigo-400 border border-indigo-500/30">
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                </span>
                Installation Guide
              </h3>
              <ol className="relative border-l border-white/10 ml-4 space-y-6">
                {[
                  'Download the APK file to your Android device.',
                  'Open Settings > Security (or Apps).',
                  'Enable "Install Unknown Apps" for your browser.',
                  'Locate the file and tap to install.',
                  'Log in with your institutional credentials.'
                ].map((step, idx) => (
                  <li key={idx} className="ml-6 text-sm text-slate-400 leading-relaxed">
                    <span className="absolute -left-3 flex items-center justify-center w-6 h-6 rounded-full bg-slate-800 ring-4 ring-slate-950 text-xs font-medium text-slate-300 border border-white/10">
                      {idx + 1}
                    </span>
                    {step}
                  </li>
                ))}
              </ol>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="relative z-10 border-t border-white/5 bg-slate-950/80 backdrop-blur-lg">
        <div className="max-w-7xl mx-auto px-6 lg:px-8 py-10 flex flex-col md:flex-row justify-between items-center gap-6">
          <div className="flex items-center gap-4 opacity-60 hover:opacity-100 transition-opacity">
            <div className="flex items-center -space-x-2">
              <Image src="/assets/ISUFST_LOGO.png" alt="ISUFST Logo" width={24} height={24} className="grayscale brightness-200" />
              <Image src="/assets/GSO.png" alt="GSO Logo" width={24} height={24} className="grayscale brightness-200" />
            </div>
            <span className="font-medium text-sm text-slate-300">ISUFST GSO • Dingle Campus</span>
          </div>

          <div className="text-sm text-slate-500 font-light text-center md:text-left">
            © {new Date().getFullYear()} Iloilo State University of Fisheries Science and Technology - Dingle Campus.
          </div>
          <div className="flex gap-6 text-sm text-slate-500">
            <a href="#" className="hover:text-indigo-400 transition-colors">Privacy</a>
            <a href="#" className="hover:text-indigo-400 transition-colors">Terms</a>
          </div>
        </div>
      </footer>
    </div>
  )
}

