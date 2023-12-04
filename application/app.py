from flask import Flask, render_template
import requests

app = Flask(__name__)

@app.route('/')
def index():
    # Replace with your Azure DevOps REST API call
    pipeline_data = get_pipeline_data()
    return render_template('index.html', data=pipeline_data)

def get_pipeline_data():
    # Use Azure DevOps REST API here
    # Example: requests.get('your-azure-devops-api-url')
    return {}

if __name__ == '__main__':
    app.run(debug=True)
