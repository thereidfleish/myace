import React from 'react'
import {Link} from 'react-router-dom'


export default function Footer() {

    return (
        <div>
            <Link to="/" style={{ paddingLeft: '1rem', paddingBottom: '1rem', textDecoration: 'none' }}>
                Home
            </Link>
            <Link to="/privacy" style={{ paddingLeft: '1rem', paddingBottom: '1rem', textDecoration: 'none' }}>
                Privacy Policy
            </Link>
        </div>
    )
}
