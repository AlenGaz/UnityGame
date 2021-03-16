using Mirror;
using UnityEngine;
using UnityEngine.UI;

public class RegistrationManager : MonoBehaviour
{
    public static RegistrationManager getInstance;
    void Awake() { getInstance = this; }

    [SerializeField] InputField emailInput, usernameInput, passwordInput;
    [SerializeField] GameObject loginPanel;

    public void Register()
    {
        string email = emailInput.text;
        string username = usernameInput.text;
        string password = passwordInput.text;

        emailInput.text = usernameInput.text = passwordInput.text = "";

        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            return;

        NetworkClient.Send(new RegistrationPacket { email = email, username = username, password = password });
    }
    public void RegistrationResponse(RegistrationResponse resp)
    {
        Debug.Log("Registration Response: " + resp);
        if (resp == global::RegistrationResponse.Successful)
            Back();
    }
    public void Back()
    {
        loginPanel.SetActive(true);
        gameObject.SetActive(false);
    }
}