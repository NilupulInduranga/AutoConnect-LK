'use server'

import { supabaseAdmin } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function holdListing(formData: FormData) {
    const reportId = formData.get('report_id') as string
    const listingId = formData.get('listing_id') as string

    // Set listing to pending
    await supabaseAdmin.from('listings').update({ status: 'pending' }).eq('id', listingId)
    // Mark report as resolved
    await supabaseAdmin.from('reported_listings').update({ status: 'resolved' }).eq('id', reportId)

    revalidatePath('/reported_listings')
    revalidatePath('/listings')
}

export async function revokeListing(formData: FormData) {
    const reportId = formData.get('report_id') as string
    const listingId = formData.get('listing_id') as string

    // Set listing to rejected
    await supabaseAdmin.from('listings').update({ status: 'rejected' }).eq('id', listingId)
    // Mark report as resolved
    await supabaseAdmin.from('reported_listings').update({ status: 'resolved' }).eq('id', reportId)

    revalidatePath('/reported_listings')
    revalidatePath('/listings')
}
