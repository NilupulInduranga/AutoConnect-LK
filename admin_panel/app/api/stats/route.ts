import { NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabaseClient'

export const dynamic = 'force-dynamic'

export async function GET() {
    try {
        const { count: users } = await supabaseAdmin.from('profiles').select('*', { count: 'exact', head: true })
        const { count: listings } = await supabaseAdmin.from('listings').select('*', { count: 'exact', head: true })
        const { count: orders } = await supabaseAdmin.from('orders').select('*', { count: 'exact', head: true })
        const { count: pendingListings } = await supabaseAdmin.from('listings').select('*', { count: 'exact', head: true }).eq('status', 'pending')

        return NextResponse.json({
            users: users ?? 0,
            listings: listings ?? 0,
            orders: orders ?? 0,
            pendingListings: pendingListings ?? 0
        })
    } catch (error) {
        return NextResponse.json({ error: 'Failed to fetch stats' }, { status: 500 })
    }
}
