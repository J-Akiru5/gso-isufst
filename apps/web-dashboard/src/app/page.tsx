import Link from 'next/link'
import Image from 'next/image'

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white selection:bg-blue-100">
      {/* Navigation */}
      <nav className="fixed top-0 w-full bg-white/80 backdrop-blur-md border-b border-gray-100 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="flex items-center gap-3">
              <Image src="/assets/GSO.png" alt="GSO Logo" width={40} height={40} className="rounded-lg shadow-sm" />
              <span className="font-bold text-xl tracking-tight text-gray-900">ISUFST GSO</span>
            </div>
            <div className="flex items-center gap-4">
              <Link
                href="/dashboard"
                className="inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 transition-all shadow-sm shadow-blue-200"
              >
                Go to Dashboard
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <main className="pt-24 pb-16 sm:pt-32 sm:pb-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-50 text-blue-700 mb-8 border border-blue-100">
              Official Portal for Dingle Campus
            </div>
            <h1 className="text-4xl sm:text-6xl font-extrabold text-gray-900 tracking-tight mb-8">
              General Services Office <br />
              <span className="text-blue-600">ISUFST - Dingle Campus</span>
            </h1>
            <p className="max-w-2xl mx-auto text-lg sm:text-xl text-gray-600 leading-relaxed mb-10">
              Modernizing campus operations through a unified digital ecosystem. Manage inventory, maintenance, and equipment borrowing with ease.
            </p>
            <div className="flex flex-col sm:flex-row justify-center gap-4">
              <Link
                href="#download"
                className="inline-flex items-center justify-center px-8 py-4 text-base font-semibold rounded-2xl text-white bg-gray-900 hover:bg-gray-800 transition-all shadow-lg shadow-gray-200"
              >
                Download Mobile App
              </Link>
              <Link
                href="/dashboard"
                className="inline-flex items-center justify-center px-8 py-4 text-base font-semibold rounded-2xl text-gray-900 bg-gray-100 hover:bg-gray-200 transition-all"
              >
                Staff Login
              </Link>
            </div>
          </div>

          {/* Feature Grid */}
          <div className="mt-24 grid grid-cols-1 gap-8 sm:grid-cols-3">
            {[
              {
                title: 'Smart Inventory',
                desc: 'Real-time tracking of campus assets and supplies with automated audit logs.',
                icon: '📦',
              },
              {
                title: 'Maintenance Hub',
                desc: 'Centralized reporting for facility repairs and campus improvement projects.',
                icon: '🛠️',
              },
              {
                title: 'Borrowing System',
                desc: 'Digital workflow for requesting and returning school equipment securely.',
                icon: '📅',
              },
            ].map((feature, i) => (
              <div key={i} className="relative group p-8 bg-white border border-gray-100 rounded-3xl hover:border-blue-100 hover:shadow-xl hover:shadow-blue-50/50 transition-all duration-300">
                <div className="text-4xl mb-6">{feature.icon}</div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">{feature.title}</h3>
                <p className="text-gray-600 leading-relaxed">{feature.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </main>

      {/* Download Section */}
      <section id="download" className="py-24 bg-gray-50 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="bg-blue-600 rounded-[2.5rem] p-8 sm:p-16 relative overflow-hidden shadow-2xl shadow-blue-200">
            <div className="relative z-10 max-w-2xl">
              <h2 className="text-3xl sm:text-4xl font-bold text-white mb-6">
                Take GSO Services <br />Everywhere You Go
              </h2>
              <p className="text-blue-100 text-lg mb-10 leading-relaxed">
                Download the ISUFST GSO mobile app for Android to stay updated on requests and manage tasks on the move.
              </p>
              <div className="flex flex-wrap gap-4">
                <a
                  href="/distribution/isufst_gso.apk"
                  className="inline-flex items-center gap-2 bg-white text-blue-600 px-8 py-4 rounded-2xl font-bold hover:bg-blue-50 transition-all shadow-lg"
                >
                  <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M17.523 15.3414L20.355 18.1734L18.941 19.5874L16.109 16.7554V21H14.109V13H22.109V15H17.523V15.3414ZM7.109 13H12.109V15H9.109V17H12.109V19H9.109V21H7.109V13ZM2 13H5V21H2V13ZM3 15V19H4V15H3Z" />
                  </svg>
                  Download APK (v1.0.0)
                </a>
                <div className="flex flex-col justify-center text-sm text-blue-200">
                  <span>File size: ~15MB</span>
                  <span>Requires Android 8.0+</span>
                </div>
              </div>
            </div>
            
            {/* Abstract Background Shapes */}
            <div className="absolute top-0 right-0 -mr-20 -mt-20 w-96 h-96 bg-blue-500 rounded-full blur-3xl opacity-50" />
            <div className="absolute bottom-0 left-0 -ml-20 -mb-20 w-64 h-64 bg-blue-400 rounded-full blur-3xl opacity-30" />
          </div>

          <div className="mt-12 p-8 border border-gray-200 rounded-3xl bg-white">
            <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
              <span className="flex items-center justify-center w-6 h-6 rounded-full bg-blue-100 text-blue-600 text-xs">i</span>
              Installation Guide for Android
            </h3>
            <ol className="list-decimal list-inside space-y-3 text-gray-600 text-sm">
              <li>Download the APK file using the button above.</li>
              <li>Open your device's <b>Settings</b> and navigate to <b>Security</b> or <b>Apps</b>.</li>
              <li>Enable <b>"Install Unknown Apps"</b> or <b>"Allow from this source"</b> for your browser/file manager.</li>
              <li>Locate the downloaded file and tap it to install.</li>
              <li>Launch <b>ISUFST GSO</b> and log in with your institutional credentials.</li>
            </ol>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row justify-between items-center gap-8">
          <div className="flex items-center gap-3 opacity-50 grayscale">
            <Image src="/assets/GSO.png" alt="GSO Logo" width={30} height={30} />
            <span className="font-bold text-sm">ISUFST GSO</span>
          </div>
          <div className="text-sm text-gray-500">
            © 2026 Iloilo State University of Fisheries Science and Technology - Dingle Campus.
          </div>
          <div className="flex gap-6 text-sm font-medium text-gray-500">
            <Link href="/privacy" className="hover:text-blue-600 transition-colors">Privacy Policy</Link>
            <Link href="/terms" className="hover:text-blue-600 transition-colors">Terms of Service</Link>
          </div>
        </div>
      </footer>
    </div>
  )
}
