export const authFetch = async (resource: string, setApiError: (_: string) => any, token: string, config: any) => {
  // request interceptor

  // prefix with backend endpoint
  let newResource = process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + resource

  // add authorization header
  let newConfig = {
    ...config,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token
    },
  }

  console.log("making request with")
  console.log(newConfig)

  let response = await fetch(newResource, newConfig)

  // response interceptor
  const json = () =>
    response
      .clone()
      .json()
  response.json = json

  if (response.status == 401) {
    const j = await response.json()
    setApiError(j.error)
  }

  return response;
}
