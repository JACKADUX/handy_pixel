class_name Utils

static func thread_call_tasks(fns:Array):
	WorkerThreadPool.add_task(func():
		for fn: Callable in fns:
			await fn.call()
	)

static func get_time_stemp() -> String:
	return Time.get_datetime_string_from_system(false, true)

static func get_time_stemp_for_name() -> String:
	return Utils.get_time_stemp().replace("-","").replace(":","").replace(" ","")
