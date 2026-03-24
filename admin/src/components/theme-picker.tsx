'use client'
type Props = { value: { primary: string; secondary: string; accent: string }
               onChange: (v: Props['value']) => void }

export function ThemePicker({ value, onChange }: Props) {
  const fields: Array<keyof Props['value']> = ['primary', 'secondary', 'accent']
  return (
    <div className="flex gap-6">
      {fields.map(field => (
        <div key={field}>
          <label className="block text-sm font-medium capitalize mb-1">{field}</label>
          <div className="flex items-center gap-2">
            <input type="color" value={value[field]}
              onChange={e => onChange({ ...value, [field]: e.target.value })}
              className="h-10 w-16 rounded cursor-pointer border" />
            <span className="text-sm font-mono text-gray-500">{value[field]}</span>
          </div>
        </div>
      ))}
    </div>
  )
}
