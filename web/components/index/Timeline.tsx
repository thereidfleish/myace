import React from 'react'
import { ArrowPathIcon, BoltIcon, CircleStackIcon, LightBulbIcon } from '@heroicons/react/24/outline'

function TimelineEntry({ title, summary, date, icon, showbar }: { title: string, summary: string, date: string, icon: React.ReactElement, showbar: boolean }) {
  return (
    <div className="grid grid-cols-3 items-center">
      {/* timeline text */}
      <div className="max-w-sm text-right mr-4 sm:mr-0 col-span-2 sm:col-span-1">

        {/* date on the left for mobile only */}
        <h3 className="font-bold text-sm sm:hidden">{date.toUpperCase()}</h3>

        <h3 className="text-2xl font-semibold dark:text-violet-400">{title}</h3>
        <h3>{summary}</h3>
      </div>

      {/* circle background */}
      <div className="w-24 h-24 sm:w-28 sm:h-28 mx-auto my-4 rounded-full flex items-center justify-center dark:border-violet-400 border-8">
        {/* overwrite the className of `icon` */}
        {React.cloneElement(icon, { className: "w-10 h-10 sm:w-16 sm:h-16" })}
      </div>

      {/* date on the right for larger screens */}
      <div className="align-middle hidden sm:flex items-center">
        <h3 className="text-left font-medium text-xl sm:text-3xl ">{date.toUpperCase()}</h3>
      </div>

      {/* connector to next entry */}
      {
        showbar &&
        (<div className="col-start-3 sm:col-start-2 w-3 sm:w-4 h-16 my-2 mx-auto dark:bg-violet-400 rounded-sm"></div>)
      }
    </div>
  )
}

export default function Timeline() {

  const timelines = [
    {
      title: "Proof of Concept",
      summary: "Initial team, application, and business development of the MyAce app.",
      date: "Jan 2022",
      icon: <LightBulbIcon />
    },
    {
      title: "Beta App Store Release",
      summary: "Launch of the first iOS beta, which targeted individual athletes.",
      date: 'May 2022',
      icon: <BoltIcon />
    },
    {
      title: "Back to the Drawing Board",
      summary: "Start to market to athletic organizations and brainstorm the future of MyAce.",
      date: 'Jul 2022',
      icon: <ArrowPathIcon />
    },
    {
      title: "Development",
      summary: "With previous experience and talent, rebuild MyAce for Android, iOS, and the Web.",
      date: 'Sep 2022',
      icon: <CircleStackIcon />
    }
  ]

  return (
    <section id="timeline" className="max-w-4xl mx-auto">
      <div className="flex justify-center mb-12">
        <h2 className="font-bold text-4xl">Project Timeline</h2>
      </div>
      <div>
        {
          timelines.map((timeline, i) => {
            return (
              <TimelineEntry
                title={timeline.title}
                summary={timeline.summary}
                date={timeline.date}
                icon={timeline.icon}
                showbar={i < timelines.length - 1}
                key={i}
              />
            )
          })
        }
      </div>
    </section>

  )
}
