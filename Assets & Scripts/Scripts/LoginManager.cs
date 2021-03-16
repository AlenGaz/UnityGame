using Mirror;
using UnityEngine;
using UnityEngine.UI;

public class LoginManager : MonoBehaviour
{
    public static LoginManager getInstance;
    void Awake() { getInstance = this; }

    [SerializeField] InputField usernameInput, passwordInput;
    [SerializeField] Toggle rememberAccount;
    [SerializeField] GameObject registrationPanel;
    [SerializeField] GameObject characterSelectionPanel;

    public static string _username = "";

    private void Start()
    {
        if (PlayerPrefs.HasKey("username_testgame"))
            usernameInput.text = PlayerPrefs.GetString("username_testgame");
        if (PlayerPrefs.HasKey("password_testgame"))
            passwordInput.text = PlayerPrefs.GetString("password_testgame");
    }

    public void Login()
    {
        string username = usernameInput.text;
        string password = passwordInput.text;

        usernameInput.text = passwordInput.text = "";

        if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            return;

        if (rememberAccount.isOn)
        {
            PlayerPrefs.SetString("username_testgame", username);
            PlayerPrefs.SetString("password_testgame", password);
            PlayerPrefs.Save();
        }

        _username = username;
        NetworkClient.Send(new LoginPacket { username = username, password = password });
    }
    public void LoginResponse(LoginResponse resp)
    {
        Debug.Log("Login Response: " + resp);
        if (resp == global::LoginResponse.Successful)
        {
            gameObject.SetActive(false);
            characterSelectionPanel.SetActive(true);
        }
        else
            _username = "";
    }
    public void Register()
    {
        registrationPanel.SetActive(true);
        gameObject.SetActive(false);
    }
}