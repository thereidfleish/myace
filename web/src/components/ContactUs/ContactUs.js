// test
export default function ContactUs() {

    return (
        <div style={{ margin: "1rem auto", maxWidth: "35rem", padding: "0 1rem", lineHeight: "1.7" }}>
            <h1>Contact Us</h1>
            <div style={{ padding: "0.5rem 0" }}>
            <p>For support or any questions:<br/>
                    Email <a href="mailto:myaceai@gmail.com" style={{ color: '#7ac07a', textDecoration: 'none' }}>myaceai@gmail.com</a><br/>
                or call Chris Price at <a href="tel:18324441653" style={{ color: '#7ac07a', textDecoration: 'none' }}>+1 (832) 444-1653</a>.
            </p>
            <address>
                <strong>MyAce.ai LLC</strong><br/>
                8 The Green Suite, A<br/>
                Dover, Delaware 19901
            </address>
            </div>
            <h2>Beta Feedback</h2>
            <iframe width="100%" height="1600px" title="Beta Feedback Form" src="https://docs.google.com/forms/d/e/1FAIpQLSf9aY2-RUsSVp3pIBqvP6dmdqVJcC9Z6LOygBFlWmEY_f213Q/viewform?embedded=true" frameBorder="0" marginHeight="0" marginWidth="0">Loading…</iframe>
        </div>
    )
}
