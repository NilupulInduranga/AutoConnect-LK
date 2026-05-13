'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'

interface Stats {
    users: number
    listings: number
    orders: number
    pendingListings: number
}

export default function RealtimeDashboard({ initialStats }: { initialStats: Stats }) {
    const [stats, setStats] = useState<Stats>(initialStats)

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const res = await fetch('/api/stats')
                if (res.ok) {
                    const data = await res.json()
                    setStats(data)
                }
            } catch (error) {
                console.error('Error fetching stats:', error)
            }
        }

        // Poll every 5 seconds
        const interval = setInterval(fetchStats, 5000)
        return () => clearInterval(interval)
    }, [])

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 w-full max-w-5xl mt-8">
            <Link href="/users" className="block">
                <div className="bg-blue-100 p-6 rounded-lg shadow-md transition-all duration-500 hover:shadow-lg hover:scale-105 cursor-pointer h-full">
                    <h2 className="text-xl font-bold text-gray-900">Total Users</h2>
                    <p className="text-4xl mt-2 text-gray-900 font-bold">{stats.users}</p>
                </div>
            </Link>

            <Link href="/listings" className="block">
                <div className="bg-green-100 p-6 rounded-lg shadow-md transition-all duration-500 hover:shadow-lg hover:scale-105 cursor-pointer h-full">
                    <h2 className="text-xl font-bold text-gray-900">Total Listings</h2>
                    <p className="text-4xl mt-2 text-gray-900 font-bold">{stats.listings}</p>
                </div>
            </Link>

            <Link href="/listings?status=pending" className="block">
                <div className="bg-yellow-100 p-6 rounded-lg shadow-md transition-all duration-500 hover:shadow-lg hover:scale-105 cursor-pointer h-full">
                    <h2 className="text-xl font-bold text-gray-900">Pending Approval</h2>
                    <p className="text-4xl mt-2 text-gray-900 font-bold">{stats.pendingListings}</p>
                </div>
            </Link>

            <div className="bg-purple-100 p-6 rounded-lg shadow-md transition-all duration-500 opacity-80" title="Orders page coming soon">
                <h2 className="text-xl font-bold text-gray-900">Total Orders</h2>
                <p className="text-4xl mt-2 text-gray-900 font-bold">{stats.orders}</p>
            </div>
        </div>
    )
}
