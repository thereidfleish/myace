import React from 'react'
import Header from '../Header/Header'
import { GoogleLogin } from 'react-google-login';


export default function Coaches() {
  const responseGoogle = async (response) => {
    console.log(`Credential: ${response.tokenId}`)
    await fetch(`${process.env.REACT_APP_BASE_REQUEST_URL}/login/`, {
      method: "POST",
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        token: response.tokenId
      })
    })
    .then(response => response.json())
    .then(data => {
      console.log(data)
    })
  }

  return (
    <div>
        <Header />
        Coaches
        Become a coach
        <GoogleLogin
          clientId={process.env.REACT_APP_GOOGLE_CLIENT_ID}
          buttonText="Login"
          onSuccess={responseGoogle}
          onFailure={responseGoogle}
          cookiePolicy={'single_host_origin'}
        />
    </div>
  )
}
