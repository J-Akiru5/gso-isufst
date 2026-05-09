import type { Metadata } from 'next'
import { RegisterForm } from '@/components/auth/register-form'

export const metadata: Metadata = {
  title: 'Request Access',
  description: 'Create an account to access the ISUFST GSO Management Portal',
}

export default function RegisterPage() {
  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">Request Access</h2>
        <p className="text-muted-foreground text-sm">
          Fill in your details below. Your account will be reviewed and activated
          by an administrator.
        </p>
      </div>
      <RegisterForm />
    </div>
  )
}
