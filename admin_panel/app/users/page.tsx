import { supabaseAdmin } from '@/lib/supabaseClient'

export const revalidate = 0

export default async function UsersPage() {
    const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers()

    if (error) {
        return <div className="text-red-500">Error loading users: {error.message}</div>
    }

    return (
        <main className="flex min-h-screen flex-col items-center p-24">
            <h1 className="text-4xl font-bold mb-8">Manage Users</h1>

            <div className="w-full max-w-5xl">
                <table className="min-w-full bg-white border border-gray-300 shadow-md rounded-lg overflow-hidden">
                    <thead className="bg-blue-600 text-white">
                        <tr>
                            <th className="py-3 px-4 uppercase font-semibold text-sm">Email</th>
                            <th className="py-3 px-4 uppercase font-semibold text-sm">Role</th>
                            <th className="py-3 px-4 uppercase font-semibold text-sm">Created At</th>
                            <th className="py-3 px-4 uppercase font-semibold text-sm">Last Sign In</th>
                            <th className="py-3 px-4 uppercase font-semibold text-sm">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="text-gray-700">
                        {users?.map((user) => (
                            <tr key={user.id} className="hover:bg-gray-100 border-b border-gray-200 transition">
                                <td className="py-3 px-4">{user.email}</td>
                                <td className="py-3 px-4">
                                    <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded text-xs">
                                        {user.user_metadata?.role || 'User'}
                                    </span>
                                </td>
                                <td className="py-3 px-4 text-sm">{new Date(user.created_at).toLocaleDateString()}</td>
                                <td className="py-3 px-4 text-sm">{user.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleDateString() : 'Never'}</td>
                                <td className="py-3 px-4">
                                    <button className="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded text-xs transition">
                                        Delete
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </main>
    )
}
