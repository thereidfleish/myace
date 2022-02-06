import Card from 'react-bootstrap/Card'

export default function FundCard(props) {
  return (
    <Card style={{ width: '290px', margin: '20px' }}>
        <Card.Body>
            <Card.Title>{props.title}</Card.Title>
            <Card.Subtitle className="mb-2 text-muted">{props.subtitle}</Card.Subtitle>
            <Card.Text>
                {props.description}
            </Card.Text>
            <span>Ready to take the next step?</span>
            <br/>
            <div className='d-flex justify-content-around'>
            {
                props.links.map((link, i) => {
                    return (
                        <Card.Link 
                            href={link.link}
                            target="_blank"
                            style={{ textDecoration: 'none'}}
                            key={i}
                        >
                            <span 
                                className="primary-color"
                            >
                                {link.text}
                            </span>
                        </Card.Link>
                    )
                })
            }
                </div>
        </Card.Body>
    </Card>
  );
}
