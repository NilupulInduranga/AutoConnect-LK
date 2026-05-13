import { supabaseAdmin } from '@/lib/supabaseClient'
import { approveListing, rejectListing, toggleVisibility } from './actions'
import { DeleteButton } from './listing-actions'

export const revalidate = 0

export default async function ListingsPage(props: { searchParams: Promise<{ seller_id?: string; status?: string }> }) {
    const searchParams = await props.searchParams;
    let query = supabaseAdmin
        .from('listings')
        .select('*, sellers(shop_name, id)') // Select shop name AND ID
        .order('created_at', { ascending: false })

    // Apply Filter if present
    if (searchParams.seller_id) {
        query = query.eq('seller_id', searchParams.seller_id)
    }
    if (searchParams.status) {
        query = query.eq('status', searchParams.status)
    }

    const { data: listings } = await query

    return (
        <main className="flex min-h-screen flex-col items-center p-24">
            <div className="flex justify-between w-full max-w-5xl mb-8 items-center">
                <h1 className="text-4xl font-bold">Manage Listings</h1>
                <div className="flex gap-4">
                    <a href="/listings?status=pending" className={`px-4 py-2 rounded ${searchParams.status === 'pending' ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-800'}`}>
                        Pending Approval
                    </a>
                    <a href="/listings" className={`px-4 py-2 rounded ${!searchParams.status ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-800'}`}>
                        All Listings
                    </a>
                </div>
            </div>

            <div className="w-full max-w-5xl">
                <table className="min-w-full bg-white border border-gray-300 shadow-md rounded-lg overflow-hidden">
                    <thead className="bg-blue-600 text-white">
                        <tr>
                            <th className="py-3 px-4 text-left uppercase font-semibold text-sm">Title</th>
                            <th className="py-3 px-4 text-left uppercase font-semibold text-sm">Shop</th>
                            <th className="py-3 px-4 text-left uppercase font-semibold text-sm">Price</th>
                            <th className="py-3 px-4 text-left uppercase font-semibold text-sm">AI Score</th>
                            <th className="py-3 px-4 text-left uppercase font-semibold text-sm">Status</th>
                            <th className="py-3 px-4 text-left uppercase font-semibold text-sm">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="text-gray-700">
                        {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                        {listings?.map((listing: any) => (
                            <tr key={listing.id} className={`hover:bg-gray-50 border-b border-gray-100 ${listing.is_hidden ? 'opacity-50 bg-gray-100' : ''}`}>
                                <td className="py-3 px-4">
                                    {listing.title}
                                    {listing.is_hidden && <span className="ml-2 text-xs bg-gray-600 text-white px-1 rounded">HIDDEN</span>}
                                </td>
                                <td className="py-3 px-4">
                                    <div className="flex flex-col">
                                        <a href={`/listings?seller_id=${listing.seller_id}`} className="font-bold text-blue-600 hover:underline">
                                            {listing.sellers?.shop_name || 'Unknown'}
                                        </a>
                                        <span className="text-xs text-gray-500">Click to filter</span>
                                    </div>
                                </td>
                                <td className="py-3 px-4">{listing.price}</td>
                                <td className="py-3 px-4">
                                    <span className={listing.ai_flag_score > 0.5 ? 'text-red-500 font-bold' : 'text-green-500'}>
                                        {listing.ai_flag_score ?? 'N/A'}
                                    </span>
                                </td>
                                <td className="py-3 px-4">
                                    <span className={`px-2 py-1 rounded text-white text-xs ${listing.status === 'approved' ? 'bg-green-500' :
                                        listing.status === 'rejected' ? 'bg-red-500' : 'bg-yellow-500'
                                        }`}>
                                        {listing.status.toUpperCase()}
                                    </span>
                                </td>
                                <td className="py-3 px-4 flex gap-2">
                                    {/* Action Buttons */}
                                    {listing.status === 'pending' && (
                                        <form action={approveListing}>
                                            <input type="hidden" name="id" value={listing.id} />
                                            <button className="bg-green-500 text-white p-1 rounded hover:bg-green-600" title="Approve">
                                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" /></svg>
                                            </button>
                                        </form>
                                    )}

                                    {/* Delete Action (Client Component) */}
                                    <DeleteButton id={listing.id} />

                                    {/* Hide/Unhide Action */}
                                    <form action={toggleVisibility}>
                                        <input type="hidden" name="id" value={listing.id} />
                                        <input type="hidden" name="currentStatus" value={listing.is_hidden?.toString()} />
                                        <button
                                            className={`p-1 rounded text-white ${listing.is_hidden ? 'bg-gray-600 hover:bg-gray-700' : 'bg-yellow-500 hover:bg-yellow-600'}`}
                                            title={listing.is_hidden ? "Unhide" : "Hide"}
                                        >
                                            {listing.is_hidden ? (
                                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path d="M10 12a2 2 0 100-4 2 2 0 000 4z" /><path fillRule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clipRule="evenodd" /></svg>
                                            ) : (
                                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M3.707 2.293a1 1 0 00-1.414 1.414l14 14a1 1 0 001.414-1.414l-1.473-1.473A10.014 10.014 0 0019.542 10C18.268 5.943 14.478 3 10 3a9.958 9.958 0 00-4.512 1.074l-1.78-1.781zm4.261 4.26l1.514 1.515a2.003 2.003 0 012.45 2.45l1.514 1.514a4 4 0 00-5.478-5.478z" clipRule="evenodd" /><path d="M12.454 16.697L9.75 13.992a4 4 0 01-3.742-3.741L2.335 6.578A9.98 9.98 0 00.458 10c1.274 4.057 5.064 7 9.542 7 .847 0 1.669-.105 2.454-.303z" /></svg>
                                            )}
                                        </button>
                                    </form>

                                    {/* Reject Action (Only if not already rejected) */}
                                    {listing.status !== 'rejected' && (
                                        <form action={rejectListing}>
                                            <input type="hidden" name="id" value={listing.id} />
                                            <button className="bg-orange-600 text-white p-1 rounded hover:bg-orange-700" title="Reject">
                                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                                    <path fillRule="evenodd" d="M13.477 14.89A6 6 0 015.11 6.524l8.367 8.368zm1.414-1.414L6.524 5.11a6 6 0 018.367 8.367zM18 10a8 8 0 11-16 0 8 8 0 0116 0z" clipRule="evenodd" />
                                                </svg>
                                            </button>
                                        </form>
                                    )}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </main>
    )
}
