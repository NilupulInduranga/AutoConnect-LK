'use client'

import { deleteListing } from '../actions' // We will need to move action to a separate file or pass it down if possible, 
// but typically Server Actions can be imported into Client Components if defined in a separate file marked 'use server'.
// However, since they were defined inline in the page, we should move them to a generic actions file or keep them in page 
// and pass the action function as a prop IF it was a standalone function. 
// But inline 'use server' functions inside a component can be tricky if passed to client components.

// Better approach for this fix:
// 1. Move the server actions to `app/listings/actions.ts` (new file).
// 2. Create `app/listings/listing-actions.tsx` (Client Component).
// 3. Import actions in both page (for other buttons) and client component.

import { deleteListing } from './actions'

export function DeleteButton({ id }: { id: string }) {
    return (
        <form action={deleteListing} onSubmit={(e) => { if(!confirm('Are you sure?')) e.preventDefault() }}>
            <input type="hidden" name="id" value={id} />
             <button className="bg-red-500 text-white p-1 rounded hover:bg-red-600" title="Delete">
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 000-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" /></svg>
            </button>
        </form>
    )
}
