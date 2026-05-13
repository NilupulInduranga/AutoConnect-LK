const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const supabaseUrl = 'https://owfrgqkpqbgoxmwrtdkv.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93ZnJncWtwcWJnb3htd3J0ZGt2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTM2NzAxMCwiZXhwIjoyMDg2OTQzMDEwfQ.kmAf0n3bF8Jo6S7ypaojZZuIVmvqZUJftVslHJ_1_SI';

const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

async function checkListings() {
    const { data, error } = await supabaseAdmin
        .from('listings')
        .select('id, title, status')
        .eq('status', 'pending');

    if (error) {
        console.log('Error:', error);
    } else {
        console.log('Pending Listings:', data.length);
        if (data.length > 0) console.log(data);
    }
}

checkListings();
