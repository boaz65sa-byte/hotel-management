'use client'
import { createContext, useContext, useState, ReactNode } from 'react'

export type Lang = 'en' | 'he'

const translations = {
  en: {
    superAdmin: 'Super Admin',
    overview: 'Overview',
    hotels: 'Hotels',
    users: 'Users',
    analytics: 'Analytics',
    auditLogs: 'Audit Logs',
    signOut: 'Sign Out',
    totalHotels: 'Total Hotels',
    totalUsers: 'Total Users',
    openTickets: 'Open Tickets',
    active: 'active',
    acrossAllHotels: 'across all hotels',
    inYourHotel: 'in your hotel',
    name: 'Name',
    email: 'Email',
    hotel: 'Hotel',
    role: 'Role',
    status: 'Status',
    actions: 'Actions',
    allUsers: 'All Users',
    createUser: '+ Create User',
    edit: 'Edit',
    activate: 'Activate',
    deactivate: 'Deactivate',
    search: 'Search',
    save: 'Save',
    cancel: 'Cancel',
    delete: 'Delete',
    language: 'Language',
  },
  he: {
    superAdmin: 'סופר אדמין',
    overview: 'סקירה כללית',
    hotels: 'מלונות',
    users: 'משתמשים',
    analytics: 'ניתוח נתונים',
    auditLogs: 'יומן ביקורת',
    signOut: 'התנתק',
    totalHotels: 'סה"כ מלונות',
    totalUsers: 'סה"כ משתמשים',
    openTickets: 'קריאות פתוחות',
    active: 'פעילים',
    acrossAllHotels: 'בכל המלונות',
    inYourHotel: 'במלון שלך',
    name: 'שם',
    email: 'אימייל',
    hotel: 'מלון',
    role: 'תפקיד',
    status: 'סטטוס',
    actions: 'פעולות',
    allUsers: 'כל המשתמשים',
    createUser: '+ צור משתמש',
    edit: 'ערוך',
    activate: 'הפעל',
    deactivate: 'השבת',
    search: 'חיפוש',
    save: 'שמור',
    cancel: 'ביטול',
    delete: 'מחק',
    language: 'שפה',
  },
}

type T = typeof translations.en

const LangContext = createContext<{
  lang: Lang
  t: T
  setLang: (l: Lang) => void
}>({ lang: 'he', t: translations.he, setLang: () => {} })

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLang] = useState<Lang>('he')
  return (
    <LangContext.Provider value={{ lang, t: translations[lang], setLang }}>
      <div dir={lang === 'he' ? 'rtl' : 'ltr'}>{children}</div>
    </LangContext.Provider>
  )
}

export function useLang() {
  return useContext(LangContext)
}
