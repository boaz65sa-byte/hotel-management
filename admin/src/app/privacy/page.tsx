import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Privacy Policy — Hotel Service',
  description: 'Privacy policy for the Hotel Service staff app by BS-Simple.',
}

export default function PrivacyPage() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-12 text-[15px] leading-7 text-zinc-800">
      <p className="text-sm text-zinc-500">BS-Simple · Roxon</p>
      <h1 className="mt-2 text-3xl font-semibold tracking-tight">Privacy Policy</h1>
      <p className="mt-2 text-sm text-zinc-500">Last updated: 31 August 2026</p>

      <p className="mt-8">
        This policy describes how <strong>BS-Simple</strong> (“we”) collects and uses
        information in the <strong>Hotel Service</strong> staff app (iOS bundle ID{' '}
        <code>com.bssimple.hotelservice</code>) and related hotel-operations tools.
        The app is for hotel employees only. It is not a consumer social app and
        is not used for advertising.
      </p>

      <h2 className="mt-10 text-xl font-semibold">Who this applies to</h2>
      <p className="mt-3">
        Staff accounts are created by the hotel or by us. Guests do not create
        accounts in this iOS app.
      </p>

      <h2 className="mt-10 text-xl font-semibold">Information we collect</h2>
      <ul className="mt-3 list-disc space-y-2 pl-6">
        <li>
          <strong>Account:</strong> email address, name, role, and a user ID used
          to sign in and show the right hotel and department.
        </li>
        <li>
          <strong>Work content:</strong> tickets, guest requests, room status,
          checklists, messages, and photos you attach (for example a photo of a
          maintenance issue taken with the camera).
        </li>
        <li>
          <strong>Device identifiers:</strong> a push-notification token and
          related device/user IDs so we can send operational alerts through
          OneSignal.
        </li>
      </ul>
      <p className="mt-3">
        We do not collect precise location, contacts, payment card numbers, or
        health data in this app. We do not use this data to track you across
        other companies’ apps or websites for advertising.
      </p>

      <h2 className="mt-10 text-xl font-semibold">How we use information</h2>
      <p className="mt-3">
        Only to operate the hotel: sign-in, assigning work, showing dashboards,
        storing ticket photos, and sending push notifications about requests and
        tickets. We do not sell personal information and we do not show ads in
        the app.
      </p>

      <h2 className="mt-10 text-xl font-semibold">Who we share it with</h2>
      <ul className="mt-3 list-disc space-y-2 pl-6">
        <li>
          <strong>Supabase</strong> — authentication, database, and file storage
          for the hotel’s own data.
        </li>
        <li>
          <strong>OneSignal</strong> — delivery of push notifications.
        </li>
        <li>
          People at the same hotel who need the information to do their job
          (managers, reception, housekeeping, maintenance), according to their
          role.
        </li>
      </ul>
      <p className="mt-3">
        We may disclose information if required by law. Hotel customer-contract
        data stays under that hotel’s control.
      </p>

      <h2 className="mt-10 text-xl font-semibold">Retention</h2>
      <p className="mt-3">
        Account and operational records are kept for as long as the hotel uses
        the service and as needed for support, security, and legal obligations.
        The hotel can ask us to deactivate a staff account.
      </p>

      <h2 className="mt-10 text-xl font-semibold">Your choices</h2>
      <p className="mt-3">
        You can ask the hotel administrator (or us) to correct your name, change
        your email, or deactivate your account. You can turn off notifications
        in iOS Settings. Ticket photos are part of the hotel’s work record.
      </p>

      <h2 className="mt-10 text-xl font-semibold">Children</h2>
      <p className="mt-3">
        The app is for adult hotel staff. We do not direct it at children under
        13, and we do not knowingly collect data from children.
      </p>

      <h2 className="mt-10 text-xl font-semibold">Contact</h2>
      <p className="mt-3">
        BS-Simple ·{' '}
        <a className="underline" href="https://bs-simple.com">
          bs-simple.com
        </a>
        <br />
        Email:{' '}
        <a className="underline" href="mailto:boaz65sa@icloud.com">
          boaz65sa@icloud.com
        </a>
      </p>
    </main>
  )
}
