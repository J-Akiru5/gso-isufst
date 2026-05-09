import type { Metadata } from 'next'
import { LoginForm } from '@/components/auth/login-form'

export const metadata: Metadata = {
  title: 'Sign In',
  description: 'Sign in to the ISUFST GSO Management Portal',
}

export default function LoginPage() {
  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">Welcome back</h2>
        <p className="text-muted-foreground text-sm">
          Sign in to your account to continue
        </p>
      </div>
      <LoginForm />
    </div>
  )
}
