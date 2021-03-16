using Mirror;
using UnityEngine;

public class Projectile : NetworkBehaviour
{
    [SerializeField] float speed = 5f;
    [SerializeField] float time = 50f;
    [SerializeField] float damage = 10f;
    public GameObject target;
    bool init = false;

    public void Init(GameObject target)
    {
        this.target = target;
        init = true;
        Invoke("destroy", time);
    }

    void Update()
    {
        Move();
    }

    public void Move()
    {
        if (!init)
            return;

        transform.position = Vector3.MoveTowards(transform.position, target.transform.position, speed * Time.deltaTime);
        transform.LookAt(target.transform);

        if (Vector3.Distance(transform.position, target.transform.position) < .1f)
        {
            if (isServer)
                target.GetComponent<_Player>().TakeDamage(damage);
            destroy();
        }
    }

    void destroy()
    {
        Destroy(gameObject);
    }
}