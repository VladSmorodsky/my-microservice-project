from django.http import HttpResponse


def home(request):
    """Home page view"""
    return HttpResponse("""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Django Docker Project</title>
            <style>
                body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
                h1 { color: #0c4b33; }
                .success { color: green; font-weight: bold; }
            </style>
        </head>
        <body>
            <h1>Django + PostgreSQL + Nginx + Docker</h1>
            <p class="success">Application is running successfully!</p>
            <ul>
                <li><a href="/admin">Admin Panel</a></li>
            </ul>
        </body>
        </html>
    """)
