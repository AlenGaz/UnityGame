using Mirror;
using UnityEngine;
using UnityEngine.UI;

public class Character : MonoBehaviour
{
    public int id { get; private set; }
    public string _name { get; private set; }

    public int profession { get; private set; }

    [SerializeField] Text nameText;

    public void Init(int id, string _name)
    {
        this.id = id;
        this._name = _name;
        nameText.text = _name;
    }

    public void Select()
    {
        if (CharacterSelection.getInstance.inCharCreation)
            return;

        SelectCharacterPacket packet = new SelectCharacterPacket();
        packet.id = id;
        NetworkClient.Send(packet);
    }
}