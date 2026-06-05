def greet(name: str) -> str:
    message = f"Hello {name}"
    return message.upper()


VALUE = 42
print(greet("Pinky"), VALUE)
