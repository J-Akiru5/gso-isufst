import type { Metadata } from 'next'
import { Clock, Mail, CheckCircle } from 'lucide-react'
import { signOutAction } from './actions'

export const metadata: Metadata = {
  title: 'Pending Approval',
}

export default function PendingApprovalPage() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-6">
      <div className="max-w-md w-full text-center space-y-8 animate-slide-up">
        {/* Icon */}
        <div className="mx-auto w-20 h-20 rounded-full bg-primary/10 flex items-center justify-center">
          <Clock className="w-10 h-10 text-primary" />
        </div>

        {/* Content */}
        <div className="space-y-3">
          <h1 className="text-2xl font-bold">Account Pending Approval</h1>
          <p className="text-muted-foreground leading-relaxed">
            Your registration request has been received. An administrator will
            review and activate your account shortly.
          </p>
        </div>

        {/* Steps */}
        <div className="text-left space-y-3 bg-muted/50 rounded-xl p-5">
          {[
            {
              icon: CheckCircle,
              color: 'text-green-500',
              title: 'Registration Submitted',
              desc: 'Your details have been recorded',
            },
            {
              icon: Clock,
              color: 'text-amber-500',
              title: 'Admin Review',
              desc: 'Usually completed within 1 business day',
            },
            {
              icon: Mail,
              color: 'text-primary',
              title: 'Email Notification',
              desc: "You'll be notified once approved",
            },
          ].map((step, i) => (
            <div key={i} className="flex items-start gap-3">
              <step.icon className={`w-5 h-5 mt-0.5 shrink-0 ${step.color}`} />
              <div>
                <p className="text-sm font-medium">{step.title}</p>
                <p className="text-xs text-muted-foreground">{step.desc}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Actions */}
        <div className="space-y-3">
          <p className="text-sm text-muted-foreground">
            For urgent matters, contact the GSO Office directly.
          </p>
          {/* Sign out via Server Action so session is cleared before hitting /login */}
          <form action={signOutAction}>
            <button
              type="submit"
              className="w-full inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2.5 text-sm font-medium hover:bg-accent hover:text-accent-foreground transition-colors"
            >
              Back to Sign In
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
