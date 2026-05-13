import { supabaseAdmin } from '@/lib/supabaseClient'
import { holdListing, revokeListing } from './actions'

export const revalidate = 0

export default async function ReportedListingsPage(props: { searchParams: Promise<{ status?: string }> }) {
    const searchParams = await props.searchParams;
    let query = supabaseAdmin
        .from('reported_listings')
        .select(`
            *,
            listings(title, seller_id, status),
            profiles(full_name, email)
        `)
        .order('created_at', { ascending: false })

    if (searchParams.status) {
        query = query.eq('status', searchParams.status)
    } else {
        query = query.eq('status', 'pending')
    }

    const { data: reports } = await query

    return (
        <main className="flex min-h-screen flex-col items-center p-12 md:p-24 bg-gray-50">
            <div className="flex justify-between w-full max-w-6xl mb-8 items-center">
                <h1 className="text-3xl font-bold text-gray-800">Reported Listings</h1>
                <div className="flex gap-4">
                    <a href="/reported_listings?status=pending" className={`px-4 py-2 rounded font-medium transition-colors ${searchParams.status !== 'resolved' ? 'bg-red-600 text-white shadow' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'}`}>
                        Pending Review
                    </a>
                    <a href="/reported_listings?status=resolved" className={`px-4 py-2 rounded font-medium transition-colors ${searchParams.status === 'resolved' ? 'bg-green-600 text-white shadow' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'}`}>
                        Resolved
                    </a>
                </div>
            </div>

            <div className="w-full max-w-6xl">
                <div className="bg-white border border-gray-200 shadow-sm rounded-xl overflow-hidden">
                    <table className="min-w-full divide-y divide-gray-200">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="py-4 px-6 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Listing</th>
                                <th className="py-4 px-6 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reported By</th>
                                <th className="py-4 px-6 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reason</th>
                                <th className="py-4 px-6 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                <th className="py-4 px-6 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200">
                            {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                            {reports?.map((report: any) => (
                                <tr key={report.id} className="hover:bg-gray-50 transition-colors">
                                    <td className="py-4 px-6">
                                        <div className="font-semibold text-gray-900">{report.listings?.title}</div>
                                        <div className="text-sm text-gray-500 mt-1">Status: <span className="font-medium">{report.listings?.status?.toUpperCase()}</span></div>
                                    </td>
                                    <td className="py-4 px-6 text-sm text-gray-700">
                                        {report.profiles?.full_name || report.profiles?.email || 'Unknown User'}
                                    </td>
                                    <td className="py-4 px-6 text-sm text-gray-700 max-w-xs truncate" title={report.reason}>
                                        {report.reason}
                                    </td>
                                    <td className="py-4 px-6">
                                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${report.status === 'resolved' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}`}>
                                            {report.status.toUpperCase()}
                                        </span>
                                    </td>
                                    <td className="py-4 px-6">
                                        <div className="flex gap-3">
                                            {report.status === 'pending' && (
                                                <>
                                                    <form action={holdListing}>
                                                        <input type="hidden" name="report_id" value={report.id} />
                                                        <input type="hidden" name="listing_id" value={report.listing_id} />
                                                        <button className="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500" title="Hold Listing (Set Pending)">
                                                            Hold Listing
                                                        </button>
                                                    </form>
                                                    <form action={revokeListing}>
                                                        <input type="hidden" name="report_id" value={report.id} />
                                                        <input type="hidden" name="listing_id" value={report.listing_id} />
                                                        <button className="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500" title="Revoke Listing (Set Rejected)">
                                                            Revoke Listing
                                                        </button>
                                                    </form>
                                                </>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {(!reports || reports.length === 0) && (
                                <tr>
                                    <td colSpan={5} className="py-12 text-center text-gray-500">
                                        <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                                            <path vectorEffect="non-scaling-stroke" strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                        </svg>
                                        <h3 className="mt-2 text-sm font-medium text-gray-900">No reports found</h3>
                                        <p className="mt-1 text-sm text-gray-500">There are currently no listings reported.</p>
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    )
}
