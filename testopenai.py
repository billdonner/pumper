
import os
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

response = openai.Completion.create(
  model="text-davinci-003",
  prompt="why is sky blue?\n",
  temperature=1,
  max_tokens=2000,
  top_p=1,
  frequency_penalty=0,
  presence_penalty=0
)
