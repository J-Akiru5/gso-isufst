export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen flex">
      {/* Left — Brand Panel */}
      <div className="hidden lg:flex lg:w-1/2 page-header-gradient flex-col items-center justify-center p-12 relative overflow-hidden">
        {/* Background geometric shapes */}
        <div className="absolute top-0 left-0 w-full h-full opacity-10">
          <div className="absolute top-10 left-10 w-64 h-64 rounded-full bg-white/20 blur-3xl" />
          <div className="absolute bottom-20 right-10 w-96 h-96 rounded-full bg-white/10 blur-3xl" />
          <div className="absolute top-1/2 left-1/3 w-48 h-48 rounded-full bg-white/15 blur-2xl" />
        </div>

        <div className="relative z-10 text-white text-center space-y-6 max-w-md">
          {/* Logo placeholder */}
          <div className="mx-auto w-24 h-24 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center border border-white/30">
            <span className="text-4xl font-bold text-white">G</span>
          </div>

          <div>
            <h1 className="text-3xl font-bold tracking-tight">ISUFST</h1>
            <p className="text-lg font-medium text-blue-100 mt-1">
              Management Portal
            </p>
          </div>

          <p className="text-blue-200 text-sm leading-relaxed">
            Iloilo State University of Fisheries and Technology — General
            Services Office. Streamlining campus maintenance, equipment
            borrowing, and inventory management.
          </p>

          <div className="flex items-center justify-center gap-3 pt-4">
            {[
              { label: 'Maintenance', icon: '🔧' },
              { label: 'Borrowing', icon: '📦' },
              { label: 'Inventory', icon: '📋' },
            ].map((item) => (
              <div
                key={item.label}
                className="bg-white/15 backdrop-blur-sm rounded-xl px-3 py-2 text-center border border-white/20"
              >
                <div className="text-xl">{item.icon}</div>
                <div className="text-xs text-blue-100 mt-1">{item.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right — Auth Form */}
      <div className="flex-1 flex items-center justify-center p-6 lg:p-12 bg-background">
        <div className="w-full max-w-md animate-slide-up">
          {/* Mobile logo */}
          <div className="lg:hidden text-center mb-8">
            <div className="mx-auto w-16 h-16 bg-primary rounded-2xl flex items-center justify-center mb-3">
              <span className="text-2xl font-bold text-primary-foreground">G</span>
            </div>
            <h1 className="text-xl font-bold">ISUFST Management Portal</h1>
          </div>

          {children}
        </div>
      </div>
    </div>
  )
}
