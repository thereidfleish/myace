import React from 'react'

export default function Team() {
  const team = [
    {
      name: 'Chris Price',
      description: 'Founder',
      picture: 'https://media-exp1.licdn.com/dms/image/C5603AQGd44T4D7sVMw/profile-displayphoto-shrink_200_200/0/1614116881005?e=1657756800&v=beta&t=89Daegj4G2TcGXujGHE_5_uC0tDPejN9iWt6wnOoyd8',
      linkedin: 'https://www.linkedin.com/in/christopher-price-59a24b178/'
    },
    {
      name: 'Adler Weber',
      description: 'Backend',
      picture: "https://media-exp1.licdn.com/dms/image/C4E03AQF4q69YbpwsSQ/profile-displayphoto-shrink_200_200/0/1623430072214?e=1657756800&v=beta&t=EhJ8bCDvOiuO58y9W6k8ulCaIOy1dnvQxkNgOFrZDSc",
      linkedin: 'https://www.linkedin.com/in/adler-weber-106a651ab/'
    },
    // {
    //   name: 'Grant Rinehimer',
    //   description: 'Backend',
    //   picture: "https://media.superhuman.com/images/_/https%3A%2F%2Flh6.googleusercontent.com%2Fr66PDijtSugTK_jQCYLXD_OGwI-OJW_oZRYlBPczQqMaWa0Pdh3vZHthGJJ1blwxp_JGxxzc1xs1KlUENMSoW4hlUIdyFkUue39t81i09cSobY3ZY8PnjT6DMFOrS2C7Mif9wYoCm0bh",
    //   linkedin: 'https://www.linkedin.com'
    // },
    {
      name: 'Reid Fleishman',
      description: 'iOS',
      picture: "https://media-exp1.licdn.com/dms/image/C4D03AQEO4fkuZOwEUg/profile-displayphoto-shrink_200_200/0/1641232103208?e=1657756800&v=beta&t=lMtN01HocUhvd4jsyl54tjzii7myG4ul_FlPASxLhck",
      linkedin: 'https://www.linkedin.com/in/thereidfleish/'
    },
    {
      name: 'Andrew Chen',
      description: 'iOS',
      picture: "https://media-exp1.licdn.com/dms/image/C4E03AQGkzME7hPJWvw/profile-displayphoto-shrink_200_200/0/1608691026962?e=1657756800&v=beta&t=xmthdSXdleQjFtiSv1FDoCaxtsJTSmAbN7U7vyzEBt8",
      linkedin: 'https://www.linkedin.com/in/andrew-chen-210a72146/'
    },
    // {
    //   name: 'Alex Godfrey',
    //   description: 'Web',
    //   picture: "https://media-exp1.licdn.com/dms/image/C5603AQEQkIucffHGSw/profile-displayphoto-shrink_200_200/0/1631155833068?e=1657756800&v=beta&t=feFMzFVFaySM3XmmiBUSmB7fK9484fyqx8P0THsLCUg",
    //   linkedin: 'https://www.linkedin.com/in/alex-godfrey-91a7251b1/'
    // }
  ]

  return (
    <div className="d-flex justify-content-center flex-wrap" style={{ padding: '0px 50px'}}>
      {
        team.map((member, i) => {
          return (
            <div style={{ margin: '20px' }} key={i} className="d-flex flex-column align-items-center">
              <h4 style={{ lineHeight: '0.6' }}>{member.name}</h4>
              <h5>{member.description}</h5>
              <a target="_blank" rel="noreferrer" href={member.linkedin}>
                <img 
                  style={{ 
                    width: '200px',
                    borderRadius: '50%', 
                    border: '3px solid #8AD28A',
                    cursor: 'pointer'
                  }} 
                  src={member.picture} 
                  alt={member.name}
                />
              </a>
            </div>
          )
        })
      }
    </div>
  )
}
