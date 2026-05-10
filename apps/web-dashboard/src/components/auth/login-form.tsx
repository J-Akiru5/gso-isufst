'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Eye, EyeOff, Loader2, LogIn } from 'lucide-react'
import { toast } from 'sonner'

import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

const loginSchema = z.object({
  email: z.string().email('Enter a valid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})

type LoginData = z.infer<typeof loginSchema>

export function LoginForm() {
  const router = useRouter()
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginData>({ resolver: zodResolver(loginSchema) })

  const onSubmit = async (data: LoginData) => {
    setIsLoading(true)
    const supabase = createClient()

    const { error } = await supabase.auth.signInWithPassword({
      email: data.email,
      password: data.password,
    })

    if (error) {
      toast.error(error.message)
      setIsLoading(false)
      return
    }

    // Check approval status
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (user) {
      const [{ data: profileData }, { data: userRolesData }] = await Promise.all([
        supabase.from('profiles').select('is_approved, is_active').eq('id', user.id).single(),
        supabase.from('user_roles').select('roles(name)').eq('user_id', user.id),
      ])
      const profile = profileData as any
      const roles = (userRolesData as any[])?.map((ur) => (ur.roles as any)?.name).filter(Boolean) ?? []
      const isSuperAdmin = roles.includes('super_admin')

      if (!profile?.is_active) {
        await supabase.auth.signOut()
        toast.error('Your account has been deactivated. Contact the administrator.')
        setIsLoading(false)
        return
      }

      if (!profile?.is_approved && !isSuperAdmin) {
        router.push('/pending-approval')
        return
      }
    }

    toast.success('Welcome back!')
    router.push('/dashboard')
    router.refresh()
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
      {/* Email */}
      <div className="space-y-2">
        <Label htmlFor="email">Institutional Email</Label>
        <Input
          id="email"
          type="email"
          placeholder="you@isufst.edu.ph"
          autoComplete="email"
          disabled={isLoading}
          className="h-11"
          {...register('email')}
        />
        {errors.email && (
          <p className="text-destructive text-xs">{errors.email.message}</p>
        )}
      </div>

      {/* Password */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <Label htmlFor="password">Password</Label>
          <Link
            href="/forgot-password"
            className="text-xs text-muted-foreground hover:text-primary transition-colors"
          >
            Forgot password?
          </Link>
        </div>
        <div className="relative">
          <Input
            id="password"
            type={showPassword ? 'text' : 'password'}
            placeholder="••••••••"
            autoComplete="current-password"
            disabled={isLoading}
            className="h-11 pr-10"
            {...register('password')}
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
          >
            {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
          </button>
        </div>
        {errors.password && (
          <p className="text-destructive text-xs">{errors.password.message}</p>
        )}
      </div>

      {/* Submit */}
      <Button
        type="submit"
        className="w-full h-11 bg-primary hover:bg-primary/90 text-primary-foreground font-medium"
        disabled={isLoading}
      >
        {isLoading ? (
          <>
            <Loader2 size={16} className="mr-2 animate-spin" />
            Signing in…
          </>
        ) : (
          <>
            <LogIn size={16} className="mr-2" />
            Sign In
          </>
        )}
      </Button>

      {/* Register link */}
      <div className="space-y-4">
        <p className="text-center text-sm text-muted-foreground">
          Don&apos;t have an account?{' '}
          <Link
            href="/register"
            className="font-medium text-primary hover:underline"
          >
            Request access
          </Link>
        </p>

        <div className="pt-4 border-t">
          <Button 
            variant="outline" 
            className="w-full h-11 border-dashed hover:border-primary hover:bg-primary/5 transition-all group"
            asChild
          >
            <a href="/downloads/isufst-gso.apk" download>
              <div className="flex items-center justify-center gap-2">
                <div className="p-1.5 rounded-md bg-muted group-hover:bg-primary/10 transition-colors">
                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <rect x="5" y="2" width="14" height="20" rx="2" ry="2" />
                    <path d="M12 18h.01" />
                  </svg>
                </div>
                <div className="text-left">
                  <p className="text-xs font-semibold leading-tight">Download Mobile App</p>
                  <p className="text-[10px] text-muted-foreground leading-tight">v1.1.0 (Android APK)</p>
                </div>
              </div>
            </a>
          </Button>
        </div>
      </div>
    </form>
  )
}
