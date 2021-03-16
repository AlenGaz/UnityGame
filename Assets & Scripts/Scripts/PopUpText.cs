using UnityEngine;
using TMPro;
using DG.Tweening;

public class PopUpText : MonoBehaviour
{
    [SerializeField] TMP_Text text;

    public void Init(float value, bool heal)
    {
        if (value < 0)
            value = -value;
        text.text = value.ToString();
        text.color = heal ? Color.green : Color.red;
        text.DOFade(0, .7f);
        transform.DOMove(transform.position + Vector3.up, 0.45f).OnComplete(() => { Destroy(gameObject);
            
        });
    }

    public void LateUpdate()
    {
        gameObject.transform.rotation = Quaternion.Euler(new Vector3(87, 0, 0));
    }
}