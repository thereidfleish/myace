import React from 'react';
import { Link } from 'react-router-dom'
import FundCard from './FundCard';
import Header from '../Header/Header'
import Timeline from '../Timeline/Timeline';

export default function Fund() {
  const fundCards = [
    {
      title: 'Individuals',
      subtitle: 'Minimum investment: $500',
      description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, ' +
        'ed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut ' +
        'enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi',
      links: [
        {
          text: 'Call Chris',
          link: 'tel:8324441653'
        },
        {
          text: 'Email Us',
          link: 'mailto:myaceai@gmail.com'
        },
      ]
    },
    {
      title: 'Venture Capital',
      subtitle: 'Minimum investment: $25,000',
      description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, ' +
        'ed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut ' +
        'enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi',
      links: [
        {
          text: 'Call Chris',
          link: 'tel:8324441653'
        },
        {
          text: 'Email Us',
          link: 'mailto:myaceai@gmail.com'
        },
      ]
    }
  ]

  return (
    <div>
      <Header />
      <div style={{ marginTop: '20px' }} className='d-flex flex-column align-items-center'>
        <h1 style={{ fontSize: '40px'}}>Funding Options</h1>
        <div style={{ width: '100%', padding: '10px' }} className="d-flex justify-content-center flex-wrap">
          {
            fundCards.map((option, i) => {
              return (
                <FundCard
                  title={option.title}
                  subtitle={option.subtitle}
                  description={option.description}
                  links={option.links}
                  key={i}
                />
              )
            })
          }
        </div>
        <p className="mb-2 text-muted">
          {'need more info about myace? visit '}
          <Link to="/about" style={{ textDecoration: 'none'}}>
            <span className="primary-color">about</span>
          </Link>
        </p>
      </div>
      <Timeline />
    </div>
    
  );
}
