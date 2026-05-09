'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Eye, EyeOff, Loader2, UserPlus } from 'lucide-react'
import { toast } from 'sonner'

import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

const registerSchema = z
  .object({
    full_name: z.string().min(3, 'Full name must be at least 3 characters'),
    email: z.string().email('Enter a valid email address'),
    employee_student_id: z.string().min(2, 'ID number is required'),
    role: z.enum(['student', 'faculty', 'technician']).optional().refine(
      (v): v is 'student' | 'faculty' | 'technician' => !!v,
      { message: 'Please select your role' }
    ),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    confirm_password: z.string(),
  })
  .refine((data) => data.password === data.confirm_password, {
    message: "Passwords don't match",
    path: ['confirm_password'],
  })

type RegisterData = z.infer<typeof registerSchema>

const ROLE_OPTIONS = [
  { value: 'student', label: 'Student' },
  { value: 'faculty', label: 'Faculty / Staff' },
  { value: 'technician', label: 'Technician / Maintenance Worker' },
]

export function RegisterForm() {
  const router = useRouter()
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<RegisterData>({ resolver: zodResolver(registerSchema) })

  const onSubmit = async (data: RegisterData) => {
    setIsLoading(true)
    const supabase = createClient()

    const { error } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          full_name: data.full_name,
          employee_student_id: data.employee_student_id,
          initial_role: data.role ?? 'student',
        },
      },
    })

    if (error) {
      toast.error(error.message)
      setIsLoading(false)
      return
    }

    // Update profile with additional fields
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (user) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (supabase as any).from('profiles').update({
        employee_student_id: data.employee_student_id,
      }).eq('id', user.id)
    }

    router.push('/pending-approval')
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {/* Full Name */}
      <div className="space-y-2">
        <Label htmlFor="full_name">Full Name</Label>
        <Input
          id="full_name"
          placeholder="Juan Dela Cruz"
          disabled={isLoading}
          className="h-11"
          {...register('full_name')}
        />
        {errors.full_name && (
          <p className="text-destructive text-xs">{errors.full_name.message}</p>
        )}
      </div>

      {/* Email */}
      <div className="space-y-2">
        <Label htmlFor="reg-email">Institutional Email</Label>
        <Input
          id="reg-email"
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

      {/* ID + Role row */}
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          <Label htmlFor="employee_student_id">ID Number</Label>
          <Input
            id="employee_student_id"
            placeholder="2024-00001"
            disabled={isLoading}
            className="h-11"
            {...register('employee_student_id')}
          />
          {errors.employee_student_id && (
            <p className="text-destructive text-xs">
              {errors.employee_student_id.message}
            </p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="role">Role</Label>
          <Select
            disabled={isLoading}
            onValueChange={(val) =>
              setValue('role', val as RegisterData['role'], {
                shouldValidate: true,
              })
            }
          >
            <SelectTrigger id="role" className="h-11">
              <SelectValue placeholder="Select…" />
            </SelectTrigger>
            <SelectContent>
              {ROLE_OPTIONS.map((opt) => (
                <SelectItem key={opt.value} value={opt.value}>
                  {opt.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.role && (
            <p className="text-destructive text-xs">{errors.role.message}</p>
          )}
        </div>
      </div>

      {/* Password */}
      <div className="space-y-2">
        <Label htmlFor="password">Password</Label>
        <div className="relative">
          <Input
            id="password"
            type={showPassword ? 'text' : 'password'}
            placeholder="Min. 8 characters"
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

      {/* Confirm Password */}
      <div className="space-y-2">
        <Label htmlFor="confirm_password">Confirm Password</Label>
        <Input
          id="confirm_password"
          type="password"
          placeholder="Repeat password"
          disabled={isLoading}
          className="h-11"
          {...register('confirm_password')}
        />
        {errors.confirm_password && (
          <p className="text-destructive text-xs">
            {errors.confirm_password.message}
          </p>
        )}
      </div>

      {/* Info box */}
      <div className="rounded-lg bg-muted p-3 text-xs text-muted-foreground">
        <strong className="text-foreground">Note:</strong> Your account will
        require admin approval before you can access the system. You will be
        notified once your account is activated.
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
            Submitting…
          </>
        ) : (
          <>
            <UserPlus size={16} className="mr-2" />
            Request Access
          </>
        )}
      </Button>

      <p className="text-center text-sm text-muted-foreground">
        Already have an account?{' '}
        <Link href="/login" className="font-medium text-primary hover:underline">
          Sign in
        </Link>
      </p>
    </form>
  )
}
