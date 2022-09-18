import { ExclamationCircleIcon, XMarkIcon } from '@heroicons/react/24/outline'
import { useContext } from 'react'
import AppErrorContext from '../lib/error-context'

export default function ErrorPopup({ error }: { error: string }) {
  const { setError } = useContext(AppErrorContext)

  return (
    // Why does the order of these utility classes matter? If I put sticky, top, and z first it does not stick
    <div className="top-3 left-3 right-3 bg-error text-error-content rounded-md shadow-lg fixed z-10 md:w-[min(36rem,60vw)] md:ml-auto md:mr-4 transition-opacity duration-[20] ease-linear">
      <div className="flex justify-between">
        <div className="ml-3 flex items-center">
          <ExclamationCircleIcon className="w-7 h-7 md:w-9 md:h-9" />
        </div>
        <p className="py-4 px-3 sm:py-6 md:py-8">{error}</p>
        <button className="h-full mr-2 mt-2" onClick={() => setError("")}>
          <XMarkIcon className="w-[1.6rem] h-[1.6rem]" />
        </button>
      </div>
    </div >
  )
}
