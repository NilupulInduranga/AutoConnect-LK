import { supabaseAdmin } from '@/lib/supabaseClient'
import RealtimeDashboard from '@/components/RealtimeDashboard'

export const revalidate = 0

export default async function Home() {
  const { data: users } = await supabaseAdmin.from('profiles').select('count')
  const { data: listings } = await supabaseAdmin.from('listings').select('count')
  const { data: orders } = await supabaseAdmin.from('orders').select('count')
  const { data: pendingListings } = await supabaseAdmin.from('listings').select('count').eq('status', 'pending')

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        <h1 className="text-4xl font-bold">AutoConnect Admin</h1>
      </div>

      <RealtimeDashboard
        initialStats={{
          users: users?.[0]?.count ?? 0,
          listings: listings?.[0]?.count ?? 0,
          orders: orders?.[0]?.count ?? 0,
          pendingListings: pendingListings?.[0]?.count ?? 0
        }}
      />

      <div className="w-full max-w-5xl mt-8">
        <h2 className="text-2xl font-bold mb-4">Quick Actions</h2>
        <div className="flex gap-4">
          <a href="/listings" className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition font-semibold shadow-lg">Manage Listings</a>
          <a href="/users" className="bg-purple-600 text-white px-6 py-3 rounded-lg hover:bg-purple-700 transition font-semibold shadow-lg">Manage Users</a>
          <a href="/reported_listings" className="bg-red-600 text-white px-6 py-3 rounded-lg hover:bg-red-700 transition font-semibold shadow-lg">Reported Listings</a>
        </div>
      </div>
    </main>
  )
}
