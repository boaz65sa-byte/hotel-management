import { requireSuperAdmin } from '@/lib/auth-guard'
import { Wizard } from './wizard'

export default async function NewHotelPage() {
  await requireSuperAdmin()
  return (
    <div className="max-w-4xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">הקמת מלון חדש</h1>
      <Wizard />
    </div>
  )
}
