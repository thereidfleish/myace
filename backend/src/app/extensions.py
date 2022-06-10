from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_cors import CORS

login_manager = LoginManager()
db = SQLAlchemy()
cors = CORS(
    origins=(
        "http://localhost:3000",
        "https://myace.ai",
        "https://www.myace.ai",
    ),
    # accept cookies from origins, makes CSRF attacks easier
    # before enabling, add some sort of CSRF protection
    # supports_credentials=True,
)
