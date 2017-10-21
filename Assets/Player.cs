using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player : MonoBehaviour {

	public float speed;
	
	Transform cam;
	CharacterController charCon;

	float fallSpeed = 0;
	float verticalCam;

	// Use this for initialization
	void Start () {
		charCon = GetComponent<CharacterController>();
		cam = Camera.main.transform;
	}
	
	void Update () {
		Mouse();
		Looking();
		Movement();
	}

	void Mouse(){
		if(Input.GetButtonDown("Fire1")){
			Cursor.lockState = CursorLockMode.Locked;
			Cursor.visible = false;
		}
		if(Input.GetButtonDown("Cancel")){
			Cursor.lockState = CursorLockMode.None;
			Cursor.visible = true;
		}
	}

	void Looking(){
		Vector2 mouseInput = new Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"));
		transform.localEulerAngles = new Vector3(0, transform.localEulerAngles.y+mouseInput.x, 0);
		verticalCam = Mathf.Clamp(verticalCam - mouseInput.y, -90, 90);
		cam.localEulerAngles = new Vector3(verticalCam, 0, 0);
	}

	void Movement(){
		fallSpeed += Physics.gravity.y * Time.deltaTime;
		Vector3 movement = new Vector3();
		movement += transform.forward * Input.GetAxis("Vertical") * speed;
		movement += transform.right * Input.GetAxis("Horizontal") * speed;
		movement.y = fallSpeed;
		charCon.Move(movement * Time.deltaTime);
	}
}
