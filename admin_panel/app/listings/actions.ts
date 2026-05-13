'use server'

import { supabaseAdmin } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function approveListing(formData: FormData) {
    const id = formData.get('id') as string
    await supabaseAdmin.from('listings').update({ status: 'approved' }).eq('id', id)
    revalidatePath('/listings')
}

export async function rejectListing(formData: FormData) {
    const id = formData.get('id') as string
    await supabaseAdmin.from('listings').update({ status: 'rejected' }).eq('id', id)
    revalidatePath('/listings')
}

export async function deleteListing(formData: FormData) {
    const id = formData.get('id') as string
    await supabaseAdmin.from('listings').delete().eq('id', id)
    revalidatePath('/listings')
}

export async function toggleVisibility(formData: FormData) {
    const id = formData.get('id') as string
    const currentStatus = formData.get('currentStatus') === 'true'

    await supabaseAdmin.from('listings').update({ is_hidden: !currentStatus }).eq('id', id)
    revalidatePath('/listings')
}
