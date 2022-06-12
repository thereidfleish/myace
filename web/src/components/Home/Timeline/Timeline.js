import React from 'react'
import TimelineEntry from './TimelineEntry'

export default function Timeline() {
  const timelines = [
      {
          contents: [
              "Development",
              "Social Media Infrastructure",
          ],
          date: "March 2022"
      },
        {
            contents: [
                "Beta App Store Release",
                "Customer Aquisition Strategy"
            ],
            date: 'June 2022'
        },
        {
            contents: [
                "Feedback Loop",
                "Demonstrated User Growth"
            ],
            date: 'July 2022'
        },
        /*{
            contents: [
                "Marketplace Release",
                "Financial Investment"
            ],
            date: 'August 2022'
        }*/
  ]

    return (
        <div>
            <h2 style={{ textAlign: 'center', marginBottom: "2vh" }}>Project Timeline</h2>
            <div id="vertical-timeline" className='d-flex justify-content-center'>
                {
                    timelines.map((timeline, i) => {
                        return (
                            <TimelineEntry
                                contents={timeline.contents}
                                date={timeline.date}
                                key={i}
                            />
                        )
                    })
                }
            </div>
            <div id="horizontal-timeline" className='d-flex justify-content-center'>
                {
                    timelines.map((timeline, i) => {
                        return (
                            <TimelineEntry
                                contents={timeline.contents}
                                date={timeline.date}
                                key={i}
                            />
                        )
                    })
                }
            </div>
        </div>
        
    )
}
